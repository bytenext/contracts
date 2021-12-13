import { emulator, init, shallPass } from 'flow-js-testing';
import path from 'path';
import { deployLaunchpad } from '../src/launchpad';
import { tx } from '../src/util';

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe('ByteNextStaking', () => {
  // Instantiate emulator and path to Cadence files
  beforeEach(async () => {
    const basePath = path.resolve(__dirname, '../cadence');
    const port = 7001;
    await init(basePath, { port });
    emulator.setLogging(true);
    return emulator.start(port, false);
  });

  // Stop emulator, so it could be restarted
  afterEach(async () => {
    return emulator.stop();
  });

  it('shall have initialized field correctly', async () => {
    // Deploy contract
    await shallPass(tx(deployLaunchpad()));
  });
});
