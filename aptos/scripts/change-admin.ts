
import { 
  AptosAccount, 
  TxnBuilderTypes, 
  BCS, 
  MaybeHexString, 
  HexString, 
  AptosClient, 
  FaucetClient,
} from "aptos";
import assert from 'assert';
import { getModuleInfo } from './utils';

export const NODE_URL = "https://fullnode.devnet.aptoslabs.com";
export const FAUCET_URL = "https://faucet.devnet.aptoslabs.com";

const client = new AptosClient(NODE_URL);

const change_admin_address = async (new_admin_address: string) => {
  
  let moduleInfo = await getModuleInfo();
  const adminAccount = new AptosAccount(
    new HexString(moduleInfo.private_key).toUint8Array()
  );
  
  console.log(`authority: ${adminAccount.address()}`);

  const payload = {
    type: 'entry_function_payload',
    function: `0x${moduleInfo.account}::MultiSender::change_admin`,
    arguments: [new_admin_address],
    type_arguments: [],
  };

  const rawTxn = await client.generateTransaction(adminAccount.address(), payload);
  const bcsTxn = await client.signTransaction(adminAccount, rawTxn);
  const transactionRes = await client.submitTransaction(bcsTxn);
  await client.waitForTransaction(transactionRes.hash);
  console.log("hash =", transactionRes.hash);
}


async function main() {
  assert(process.argv.length == 3, "Expecting an argument that points to the new admin address");
  let new_admin_address = process.argv[2];
  await change_admin_address(new_admin_address);
}

if (require.main === module) {
  main()
    .then(() => console.log("main is called"))
    .catch((e: any) => console.error(e));
}



