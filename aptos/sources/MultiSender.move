module MultiSender::MultiSender {
  
  use aptos_framework::coin;
  use aptos_framework::aptos_coin;

  const INFO_SEED: vector<u8> = b"INFO_SEED";
  const DEFAULT_APT_FEE = 100_000; /// 0.001 APT
  
  // these are error codes
  const EINVALID_ADMIN = 1;

  struct GlobalInfo has key {
      admin_addr: address,
      // project account signer_cap
      signer_cap: account::SignerCapability,
      // Fee amount in aptos
      transfer_fee: u64,
      // collected fees
      fees: coin::Coin<AptosCoin>
  }

  // constructor
  fun init_module(sender: &signer) {
      let admin_addr = signer::address_of(sender);
      let (_, signer_cap) = account::create_resource_account(sender, INFO_SEED);
      move_to<GlobalInfo>(sender, GlobalInfo {
        admin_addr,
        signer_cap,
        transfer_fee: DEFAULT_APT_FEE,
        fees: coin::zero<AptosCoin>()
      });
  }

  // only-admin
  public entry fun change_admin(sender: &signer, new_admin_addr: address) acquires GlobalInfo {
    let sender_addr = signer::address_of(sender);
    let info_addr = account::create_resource_address(&@MultiSender, INFO_SEED);
    let global_info = borrow_global_mut<GlobalInfo>(info_addr);
    assert!(sender_addr == global_info.admin_addr, error::invalid_argument(EINVALID_ADMIN));
    global_info.admin_addr = new_admin_addr;
  }

  // only-admin
  public entry fun withdraw(sender: &signer) acquires GlobalInfo {
    let sender_addr = signer::address_of(sender);
    let info_addr = account::create_resource_address(&@MultiSender, INFO_SEED);
    let global_info = borrow_global_mut<GlobalInfo>(info_addr);
    assert!(sender_addr == global_info.admin_addr, error::invalid_argument(EINVALID_ADMIN));

    let fee_coin = coin::extract<AptosCoin>(&mut global_info.fees, coin::value(global_info.fees));
    coin::deposit<AptosCoin>(sender_addr, fee_coin);
  }
  
  // only-admin
  public entry fun update_fee(sender: &signer, new_fee: u64) acquires GlobalInfo {
    let sender_addr = signer::address_of(sender);
    let info_addr = account::create_resource_address(&@MultiSender, INFO_SEED);
    let global_info = borrow_global_mut<GlobalInfo>(info_addr);
    assert!(sender_addr == global_info.admin_addr, error::invalid_argument(EINVALID_ADMIN));
    global_info.transfer_fee = new_fee;
  }

  // no limit
  public entry fun transfer_coin<CoinType>(sender: &signer, to: address, amount: u64) acquires GlobalInfo {

    let info_addr = account::create_resource_address(&@MultiSender, INFO_SEED);
    let global_info = borrow_global_mut<GlobalInfo>(info_addr);
    
    // cut fee here
    let fee_apt = coin::withdraw<AptosCoin>(sender, global_info.transfer_fee);
    coin::merge<AptosCoin>(&mut global_info.fees, fee_apt);

    // transfer
    coin::transfer<CoinType>(sender, to, amount)
  }
}