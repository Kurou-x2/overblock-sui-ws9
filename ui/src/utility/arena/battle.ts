import { Transaction } from '@mysten/sui/transactions';

export const battle = (packageId: string, heroId: string, arenaId: string) => {
  const tx = new Transaction();

  tx.moveCall({
    target: `${packageId}::arena::battle`,
    arguments: [tx.object(heroId), tx.object(arenaId)],
  });

  return tx;
};