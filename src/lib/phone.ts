/**
 * Turns what someone typed into an Indian mobile number in E.164 form (+91XXXXXXXXXX),
 * or null if it isn't one. Accepts spaces, dashes, a leading 0, or a leading 91/+91.
 */
export function toIndianMobile(input: string): string | null {
  let digits = input.replace(/\D/g, '');
  if (digits.length === 12 && digits.startsWith('91')) digits = digits.slice(2);
  if (digits.length === 11 && digits.startsWith('0')) digits = digits.slice(1);
  return /^[6-9]\d{9}$/.test(digits) ? `+91${digits}` : null;
}

/** +919876543210 -> "+91 98765 43210" */
export function formatIndianMobile(phone: string | null | undefined): string {
  if (!phone) return '';
  const digits = phone.replace(/\D/g, '');
  const local = digits.length === 12 && digits.startsWith('91') ? digits.slice(2) : digits;
  if (local.length !== 10) return phone;
  return `+91 ${local.slice(0, 5)} ${local.slice(5)}`;
}
