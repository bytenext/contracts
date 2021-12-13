import { executeScript, getAccountAddress } from 'flow-js-testing';

const UFIX64_PRECISION = 8;

// UFix64 values shall be always passed as strings
export const toUFix64 = (value) => value.toFixed(UFIX64_PRECISION);

export function getAdminAddress() {
  return getAccountAddress('admin');
}
export const sansPrefix = (address) => {
  if (address == null) return null;
  return address.replace(/^0x/, '');
};

export const withPrefix = (address) => {
  if (address == null) return null;
  return '0x' + sansPrefix(address);
};

export async function tx(fn) {
  let data, error;
  if (typeof fn == 'function') {
    [data, error] = await fn();
  } else {
    [data, error] = await fn;
  }

  if (error) {
    throw new Error(error);
  }
  return [data];
}

export async function getCurrentTimestamp() {
  return (
    await executeScript({
      code: `
    pub fun main(): UFix64 {
      return getCurrentBlock().timestamp
    }
  `
    })
  )[0];
}

export async function getBlockHeight() {
  return (
    await executeScript({
      code: `
    pub fun main(): UInt64 {
      return getCurrentBlock().height
    }
  `
    })
  )[0];
}

export async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
