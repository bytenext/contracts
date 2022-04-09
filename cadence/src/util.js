import { deployContract, executeScript, getAccountAddress, getContractCode } from "flow-js-testing";
import { mintBnu, setupBnuOnAccount } from "./bnu";
import * as fs from 'fs';
import { resolve } from "path";

const UFIX64_PRECISION = 8;

// UFix64 values shall be always passed as strings
export const toUFix64 = (value) => value.toFixed(UFIX64_PRECISION);

export function getAdminAddress() {
  return getAccountAddress("admin");
}
export const sansPrefix = (address) => {
  if (address == null) return null;
  return address.replace(/^0x/, "");
};

export const withPrefix = (address) => {
  if (address == null) return null;
  return "0x" + sansPrefix(address);
};

export async function tx(fn) {
  let data, error;
  if (typeof fn == "function") {
    [data, error] = await fn();
  } else {
    [data, error] = await fn;
  }

  if (error) {
    throw error;
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

export async function waitToTimeOver(unix) {
  const addr = await getAccountAddress("some-one-else");
  await setupBnuOnAccount(addr);
  await mintBnu(addr, 100);

  while (+(await getCurrentTimestamp()) < unix) {
    setImmediate(async () => {
      await mintBnu(addr, 100);
    });
    await sleep(100);
  }
}

export async function getCode(path) {
  return fs.promises.readFile(resolve("cadence", "contracts", path), 'utf-8');
}

export async function deployNested({ path, name = '', ...o }) {
 const code = await getContractCode({
   name: path,
   addressMap: o.addressMap || {}
 });

 delete o.addressMap

  return deployContract({
    ...o,
    name: name || path.split("/").pop(),
    code: code
  });

}
