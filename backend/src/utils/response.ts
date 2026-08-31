import { Env } from '../types';

export function corsHeaders(origin: string): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

export function json(data: unknown, status = 200, origin?: string): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin ?? '*') },
  });
}

export function success(data: unknown, message?: string, origin?: string): Response {
  return json({ success: true, data, message }, 200, origin);
}

export function created(data: unknown, origin?: string): Response {
  return json({ success: true, data }, 201, origin);
}

export function error(message: string, status: number, code?: string, origin?: string): Response {
  return json({ success: false, error: { code: code || 'ERROR', message } }, status, origin);
}

export function notFound(entity = 'Data', origin?: string): Response {
  return error(`${entity} tidak ditemukan`, 404, 'NOT_FOUND', origin);
}

export function badRequest(message: string, origin?: string): Response {
  return error(message, 400, 'BAD_REQUEST', origin);
}

export function unauthorized(origin?: string): Response {
  return error('Unauthorized', 401, 'UNAUTHORIZED', origin);
}

export function forbidden(origin?: string): Response {
  return error('Forbidden: insufficient role', 403, 'FORBIDDEN', origin);
}

export function cors(origin?: string): Response {
  return new Response(null, { status: 204, headers: corsHeaders(origin ?? '*') });
}

export function resolveCorsOrigin(requestOrigin: string | null, env: Env): string {
  const allowedOriginsRaw = env.CORS_ORIGIN || '*';
  if (allowedOriginsRaw === '*') return '*';

  const allowedOrigins = allowedOriginsRaw.split(',').map((o: string) => o.trim());

  // Origin tidak dikirim (same-origin / non-browser) → pakai origin pertama yang diizinkan
  if (!requestOrigin) return allowedOrigins[0] || '*';

  // Origin: null (string "null") dari webview/iframe/sandbox → jangan echo,
  // kembalikan origin pertama yang diizinkan agar ACAO tidak menjadi "null".
  if (requestOrigin.toLowerCase() === 'null') return allowedOrigins[0] || '*';

  // Cocokkan origin request dengan daftar yang diizinkan
  const matched = allowedOrigins.find((o: string) => o === requestOrigin);
  if (matched) return matched;

  // Origin tidak dikenal → jangan echo origin tersebut (celah CORS).
  // Kembalikan origin pertama yang diizinkan (browser akan menolak bila beda).
  return allowedOrigins[0] || '*';
}