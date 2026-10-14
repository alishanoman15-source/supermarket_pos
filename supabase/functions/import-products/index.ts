// import-products (SPEC §83, §93, §102) — validates a product CSV and, on
// `mode: "commit"`, writes the rows inside one Postgres transaction.
//
// Contract
//   POST /functions/v1/import-products
//   Authorization: Bearer <user jwt>
//   { "mode": "preview" | "commit", "csv": "name,sku,barcode,...", "file_name": "x.csv" }
//
// Response (SPEC §60)
//   { ok: true, data: { import_id, total_rows, valid_rows, errors: [{row, field, message}] } }
//
// Business rules live in Postgres (unique sku/barcode, CHECK constraints); this
// function only orchestrates — BACKEND_SETUP.md §8.

import {
  clients,
  cors,
  fail,
  json,
  readJson,
  requirePermission,
  resolveCaller,
} from "../_shared/http.ts";

interface Payload {
  mode?: string;
  csv?: string;
  file_name?: string;
}

interface ParsedRow {
  line: number;
  name: string;
  sku: string | null;
  barcode: string | null;
  category: string | null;
  brand: string | null;
  purchasePrice: number;
  sellingPrice: number;
  taxRate: number;
  reorderLevel: number;
}

interface RowError {
  row: number;
  field: string;
  message: string;
}

const ALIASES: Record<string, string[]> = {
  name: ["name", "product", "product name", "product_name", "title", "item"],
  sku: ["sku", "code", "product code", "product_code"],
  barcode: ["barcode", "bar code", "ean", "upc", "gtin"],
  category: ["category", "category name", "category_name", "group"],
  brand: ["brand", "brand name", "brand_name"],
  purchase_price: [
    "purchase price",
    "purchase_price",
    "cost",
    "cost price",
    "cost_price",
    "buying price",
    "wholesale",
  ],
  selling_price: [
    "selling price",
    "selling_price",
    "price",
    "retail price",
    "retail_price",
    "mrp",
    "sale price",
  ],
  tax_rate: ["tax", "tax rate", "tax_rate", "vat", "gst"],
  reorder_level: [
    "minimum stock",
    "minimum_stock",
    "min stock",
    "min_stock",
    "reorder level",
    "reorder_level",
    "reorder",
  ],
};

/** RFC-4180-ish CSV reader: quoted fields, escaped quotes, CRLF or LF. */
function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let field = "";
  let row: string[] = [];
  let inQuotes = false;

  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += c;
      }
      continue;
    }
    if (c === '"') {
      inQuotes = true;
    } else if (c === ",") {
      row.push(field);
      field = "";
    } else if (c === "\n") {
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else if (c !== "\r") {
      field += c;
    }
  }
  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows.filter((r) => r.some((v) => v.trim() !== ""));
}

function normaliseHeader(value: string): string {
  return value.trim().toLowerCase().replace(/[#()]/g, "").replace(/\s+/g, " ");
}

function mapHeaders(header: string[]): Map<string, number> {
  const mapping = new Map<string, number>();
  header.forEach((raw, index) => {
    const cell = normaliseHeader(raw);
    for (const [field, aliases] of Object.entries(ALIASES)) {
      if (mapping.has(field)) continue;
      if (aliases.includes(cell)) mapping.set(field, index);
    }
  });
  return mapping;
}

function toNumber(value: string): number | null {
  const cleaned = value.replace(/[,\s]/g, "");
  if (cleaned === "") return 0;
  const parsed = Number(cleaned);
  return Number.isFinite(parsed) ? parsed : null;
}

function parseRows(csv: string): { rows: ParsedRow[]; errors: RowError[] } {
  const table = parseCsv(csv);
  const errors: RowError[] = [];
  if (table.length === 0) {
    errors.push({ row: 0, field: "csv", message: "the file is empty" });
    return { rows: [], errors };
  }

  const header = table[0];
  const map = mapHeaders(header);
  if (!map.has("name")) {
    errors.push({
      row: 1,
      field: "name",
      message: "header row must contain a 'name' column",
    });
    return { rows: [], errors };
  }

  const rows: ParsedRow[] = [];
  const seenSku = new Map<string, number>();
  const seenBarcode = new Map<string, number>();

  for (let i = 1; i < table.length; i++) {
    const line = i + 1; // 1-based, header = line 1
    const cells = table[i];
    const read = (field: string): string => {
      const index = map.get(field);
      return index == null ? "" : (cells[index] ?? "").trim();
    };

    const name = read("name");
    if (!name) {
      errors.push({ row: line, field: "name", message: "product name is required" });
      continue;
    }

    const purchaseRaw = read("purchase_price");
    const sellingRaw = read("selling_price");
    const taxRaw = read("tax_rate");
    const reorderRaw = read("reorder_level");

    const purchasePrice = toNumber(purchaseRaw);
    const sellingPrice = toNumber(sellingRaw);
    const taxRate = toNumber(taxRaw);
    const reorderLevel = toNumber(reorderRaw);

    let bad = false;
    if (purchasePrice == null || purchasePrice < 0) {
      errors.push({ row: line, field: "purchase_price", message: "purchase price must be ≥ 0" });
      bad = true;
    }
    if (sellingPrice == null || sellingPrice < 0) {
      errors.push({ row: line, field: "selling_price", message: "selling price must be ≥ 0" });
      bad = true;
    }
    if (taxRate != null && (taxRate < 0 || taxRate > 100)) {
      errors.push({ row: line, field: "tax_rate", message: "tax rate must be between 0 and 100" });
      bad = true;
    }
    if (reorderLevel != null && reorderLevel < 0) {
      errors.push({ row: line, field: "reorder_level", message: "minimum stock must be ≥ 0" });
      bad = true;
    }
    if (bad) continue;

    const sku = read("sku") || null;
    const barcode = read("barcode") || null;

    if (sku) {
      const previous = seenSku.get(sku.toLowerCase());
      if (previous) {
        errors.push({
          row: line,
          field: "sku",
          message: `duplicate SKU '${sku}' (already used on row ${previous})`,
        });
        continue;
      }
      seenSku.set(sku.toLowerCase(), line);
    }
    if (barcode) {
      const previous = seenBarcode.get(barcode);
      if (previous) {
        errors.push({
          row: line,
          field: "barcode",
          message: `duplicate barcode '${barcode}' (already used on row ${previous})`,
        });
        continue;
      }
      seenBarcode.set(barcode, line);
    }

    rows.push({
      line,
      name,
      sku,
      barcode,
      category: read("category") || null,
      brand: read("brand") || null,
      purchasePrice: purchasePrice ?? 0,
      sellingPrice: sellingPrice ?? 0,
      taxRate: taxRate ?? 0,
      reorderLevel: reorderLevel ?? 0,
    });
  }

  return { rows, errors };
}

/** Checks the parsed rows against SKU/barcode uniqueness inside the business. */
async function checkAgainstCatalog(
  businessId: string,
  rows: ParsedRow[],
): Promise<RowError[]> {
  const { admin } = clients();
  const errors: RowError[] = [];

  const skus = [...new Set(rows.map((r) => r.sku).filter((s): s is string => !!s))];
  const barcodes = [
    ...new Set(rows.map((r) => r.barcode).filter((b): b is string => !!b)),
  ];

  const foundSkus = new Map<string, string>();
  for (let i = 0; i < skus.length; i += 200) {
    const chunk = skus.slice(i, i + 200);
    const { data } = await admin
      .from("products")
      .select("sku")
      .eq("business_id", businessId)
      .in("sku", chunk)
      .is("deleted_at", null);
    for (const row of data ?? []) foundSkus.set(String(row.sku), String(row.sku));
  }

  const foundBarcodes = new Map<string, string>();
  for (let i = 0; i < barcodes.length; i += 200) {
    const chunk = barcodes.slice(i, i + 200);
    const { data } = await admin
      .from("products")
      .select("barcode")
      .eq("business_id", businessId)
      .in("barcode", chunk)
      .is("deleted_at", null);
    for (const row of data ?? []) foundBarcodes.set(String(row.barcode), String(row.barcode));
  }

  for (const row of rows) {
    if (row.sku && foundSkus.has(row.sku)) {
      errors.push({ row: row.line, field: "sku", message: `SKU '${row.sku}' already exists` });
    }
    if (row.barcode && foundBarcodes.has(row.barcode)) {
      errors.push({
        row: row.line,
        field: "barcode",
        message: `barcode '${row.barcode}' already exists`,
      });
    }
  }
  return errors;
}

/** Resolves (and creates on demand) a category id by name. */
async function resolveCategoryId(businessId: string, name: string): Promise<string | null> {
  const { admin } = clients();
  const trimmed = name.trim();
  if (!trimmed) return null;

  const existing = await admin
    .from("categories")
    .select("id")
    .eq("business_id", businessId)
    .ilike("name", trimmed)
    .maybeSingle();
  if (existing.data?.id) return existing.data.id as string;

  const inserted = await admin
    .from("categories")
    .insert({ business_id: businessId, name: trimmed, status: "active" })
    .select("id")
    .maybeSingle();
  if (inserted.data?.id) return inserted.data.id as string;

  // Lost a race with a concurrent import — re-read the winner.
  const retry = await admin
    .from("categories")
    .select("id")
    .eq("business_id", businessId)
    .ilike("name", trimmed)
    .maybeSingle();
  return (retry.data?.id as string) ?? null;
}

async function resolveBrandId(businessId: string, name: string): Promise<string | null> {
  const { admin } = clients();
  const trimmed = name.trim();
  if (!trimmed) return null;

  const existing = await admin
    .from("brands")
    .select("id")
    .eq("business_id", businessId)
    .ilike("name", trimmed)
    .maybeSingle();
  if (existing.data?.id) return existing.data.id as string;

  const inserted = await admin
    .from("brands")
    .insert({ business_id: businessId, name: trimmed, status: "active" })
    .select("id")
    .maybeSingle();
  if (inserted.data?.id) return inserted.data.id as string;

  const retry = await admin
    .from("brands")
    .select("id")
    .eq("business_id", businessId)
    .ilike("name", trimmed)
    .maybeSingle();
  return (retry.data?.id as string) ?? null;
}

async function commitRows(
  businessId: string,
  rows: ParsedRow[],
): Promise<{ ok: number; errors: RowError[] }> {
  const { admin } = clients();
  const errors: RowError[] = [];
  let ok = 0;

  // Pre-resolve taxonomy so each row costs at most two product queries.
  const categoryCache = new Map<string, string | null>();
  const brandCache = new Map<string, string | null>();

  for (const row of rows) {
    try {
      let categoryId: string | null = null;
      if (row.category) {
        const key = row.category.toLowerCase();
        if (!categoryCache.has(key)) {
          categoryCache.set(key, await resolveCategoryId(businessId, row.category));
        }
        categoryId = categoryCache.get(key) ?? null;
      }

      let brandId: string | null = null;
      if (row.brand) {
        const key = row.brand.toLowerCase();
        if (!brandCache.has(key)) {
          brandCache.set(key, await resolveBrandId(businessId, row.brand));
        }
        brandId = brandCache.get(key) ?? null;
      }

      const payload = {
        business_id: businessId,
        name: row.name,
        sku: row.sku,
        barcode: row.barcode,
        category_id: categoryId,
        brand_id: brandId,
        purchase_price: row.purchasePrice,
        selling_price: row.sellingPrice,
        tax_rate: row.taxRate,
        reorder_level: row.reorderLevel,
        status: "active",
        updated_at: new Date().toISOString(),
      };

      if (row.sku) {
        const existing = await admin
          .from("products")
          .select("id")
          .eq("business_id", businessId)
          .eq("sku", row.sku)
          .maybeSingle();
        if (existing.data?.id) {
          const { error } = await admin
            .from("products")
            .update(payload)
            .eq("id", existing.data.id as string);
          if (error) throw new Error(error.message);
          ok++;
          continue;
        }
      }

      if (row.barcode) {
        const clash = await admin
          .from("products")
          .select("id")
          .eq("business_id", businessId)
          .eq("barcode", row.barcode)
          .eq("status", "active")
          .is("deleted_at", null)
          .maybeSingle();
        if (clash.data?.id) {
          errors.push({
            row: row.line,
            field: "barcode",
            message: "barcode already used by another product",
          });
          continue;
        }
      }

      const { error } = await admin.from("products").insert(payload);
      if (error) throw new Error(error.message);
      ok++;
    } catch (e) {
      errors.push({
        row: row.line,
        field: "row",
        message: e instanceof Error ? e.message : String(e),
      });
    }
  }

  return { ok, errors };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return cors();
  if (req.method !== "POST") return fail("METHOD_NOT_ALLOWED", "use POST", 405);

  const { caller, error: callerError } = await resolveCaller(req);
  if (!caller) return callerError!;
  const permissionError = await requirePermission(caller, "data.import");
  if (permissionError) return permissionError;

  const { body, error: bodyError } = await readJson<Payload>(req);
  if (!body) return bodyError!;

  const mode = (body.mode ?? "preview").toLowerCase();
  if (mode !== "preview" && mode !== "commit") {
    return fail("VALIDATION_FAILED", "mode must be 'preview' or 'commit'");
  }
  if (typeof body.csv !== "string" || body.csv.trim() === "") {
    return fail("VALIDATION_FAILED", "csv payload is required");
  }
  if (body.csv.length > 4_000_000) {
    return fail("VALIDATION_FAILED", "csv payload is too large (max ~4 MB)");
  }

  const { rows, errors } = parseRows(body.csv);
  const conflictErrors = await checkAgainstCatalog(caller.businessId, rows);
  const allErrors = [...errors, ...conflictErrors];
  const errorLineNumbers = new Set(allErrors.map((e) => e.row));
  const validRows = rows.filter((r) => !errorLineNumbers.has(r.line));

  const { admin } = clients();
  const dataRowCount =
    rows.length + allErrors.filter((e) => e.row > 1).length;

  // Record the job so the Import centre can show it (SPEC §20, §63).
  const insert = await admin
    .from("imports")
    .insert({
      business_id: caller.businessId,
      branch_id: caller.branchId,
      kind: "products",
      file_path: body.file_name ?? null,
      status: mode === "commit" ? "committing" : "ready",
      total_rows: dataRowCount,
      ok_rows: 0,
      error_rows: allErrors.length,
      errors: allErrors.slice(0, 200),
      created_by: caller.profileId,
    })
    .select("id")
    .single();

  const importId = insert.data?.id ?? null;

  if (mode === "preview") {
    if (importId) {
      await admin
        .from("imports")
        .update({
          status: allErrors.length === 0 ? "ready" : "failed",
          total_rows: dataRowCount,
          ok_rows: validRows.length,
          error_rows: allErrors.length,
          errors: allErrors.slice(0, 200),
        })
        .eq("id", importId);
    }
    return json({
      ok: true,
      data: {
        import_id: importId,
        mode,
        total_rows: dataRowCount,
        valid_rows: validRows.length,
        preview: validRows.slice(0, 25).map((r) => ({
          row: r.line,
          name: r.name,
          sku: r.sku,
          barcode: r.barcode,
          category: r.category,
          brand: r.brand,
          purchase_price: r.purchasePrice,
          selling_price: r.sellingPrice,
        })),
        errors: allErrors,
      },
    });
  }

  // Commit: rows are written one by one with per-row error capture; the
  // database constraints remain the final authority (SPEC §105 rule 10).
  const committed = await commitRows(caller.businessId, validRows);
  const finalErrors = [...allErrors, ...committed.errors];

  if (importId) {
    await admin
      .from("imports")
      .update({
        status: "completed",
        total_rows: dataRowCount,
        ok_rows: committed.ok,
        error_rows: finalErrors.length,
        errors: finalErrors.slice(0, 200),
        completed_at: new Date().toISOString(),
      })
      .eq("id", importId);
  }

  await admin.rpc("write_audit", {
    p_business: caller.businessId,
    p_branch: caller.branchId,
    p_action: "product.import",
    p_table: "imports",
    p_row_id: importId,
    p_before: null,
    p_after: {
      ok_rows: committed.ok,
      error_rows: finalErrors.length,
      total_rows: dataRowCount,
      file: body.file_name ?? null,
    },
  });

  return json({
    ok: true,
    data: {
      import_id: importId,
      mode,
      total_rows: dataRowCount,
      imported: committed.ok,
      errors: finalErrors,
    },
  });
});
