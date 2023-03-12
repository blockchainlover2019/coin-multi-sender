
import readYamlFile from 'read-yaml-file';

export const getModuleInfo = async () => {
  let configData: Config = await readYamlFile('.aptos/config.yaml');
  return configData.profiles.default;
}

type Config = {
  profiles: {
    default: {
      private_key: string,
      public_key: string,
      account: string,
      rest_url: string,
      faucet_url: string
    }
  }
}

