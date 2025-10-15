// Type declarations for Clarinet SDK globals

declare global {
  var simnet: {
    getAccounts(): Map<string, string>;
    callPublicFn(
      contractName: string,
      functionName: string,
      args: any[],
      sender: string
    ): { result: any };
    callReadOnlyFn(
      contractName: string,
      functionName: string,
      args: any[],
      sender: string
    ): { result: any };
  };
}

export {};
