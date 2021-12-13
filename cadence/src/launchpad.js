import { deployContractByName } from 'flow-js-testing';
import { getAdminAddress } from './util';

export const deployLaunchpad = async () => {
  const addr = await getAdminAddress();

  return deployContractByName({
    to: addr,
    name: 'ByteNextLaunchpad'
  });
};
