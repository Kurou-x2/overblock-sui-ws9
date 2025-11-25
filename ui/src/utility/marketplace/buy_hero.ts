import { Transaction } from '@mysten/sui/transactions';

export const buyHero = (
  packageId: string,
  listHeroId: string,
  priceInSui: string
) => {
  const tx = new Transaction();

  const priceInMist = BigInt(parseFloat(priceInSui) * 1_000_000_000);

  const [paymentCoin] = tx.splitCoins(tx.gas, [priceInMist]);

  tx.moveCall({
    target: `${packageId}::marketplace::buy_hero`,
    arguments: [tx.object(listHeroId), paymentCoin],
  });

  return tx;
};