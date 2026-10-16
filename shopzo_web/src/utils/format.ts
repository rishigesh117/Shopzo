export function formatMoney(paise: number = 0): string {
  const rupees = (paise / 100).toFixed(2);
  return `₹${rupees}`;
}

export function parseMoneyToPaise(rupees: number | string): number {
  const num = typeof rupees === 'string' ? parseFloat(rupees) : rupees;
  if (isNaN(num)) return 0;
  return Math.round(num * 100);
}

export function formatDate(timestamp: number): string {
  if (!timestamp) return '—';
  const d = new Date(timestamp);
  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatDateOnly(timestamp: number): string {
  if (!timestamp) return '—';
  const d = new Date(timestamp);
  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export function uuid(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export function generateBillNumber(existingBills?: { billNumber?: string }[]): string {
  let maxNum = 1000;
  if (existingBills && Array.isArray(existingBills)) {
    existingBills.forEach((b) => {
      if (b.billNumber) {
        const clean = b.billNumber.replace(/^#/, '');
        const num = parseInt(clean, 10);
        if (!isNaN(num) && num > maxNum) {
          maxNum = num;
        }
      }
    });
  }
  return `#${maxNum + 1}`;
}

export function getStockStatus(quantity: number, minStockLevel: number): 'OUT_OF_STOCK' | 'LOW_STOCK' | 'IN_STOCK' {
  if (quantity <= 0) return 'OUT_OF_STOCK';
  if (quantity <= minStockLevel) return 'LOW_STOCK';
  return 'IN_STOCK';
}
