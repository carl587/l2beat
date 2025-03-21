import { EthereumAddress, ProjectId, UnixTime } from '@l2beat/shared-pure'
import { BADGES } from '../../common/badges'
import type { ScalingProject } from '../../internalTypes'
import { underReviewL3 } from '../../templates/underReview'

export const xrone: ScalingProject = underReviewL3({
  id: 'xrone',
  capability: 'universal',
  addedAt: UnixTime(1737469445), // 2025-01-21T14:24:03+00:00
  hostChain: ProjectId('arbitrum'),
  badges: [
    BADGES.RaaS.Caldera,
    BADGES.L3ParentChain.Arbitrum,
    BADGES.DA.DAC,
    BADGES.Stack.Orbit,
    BADGES.VM.EVM,
  ],
  display: {
    name: 'XR One',
    slug: 'xrone',
    category: 'Optimium',
    stack: 'Arbitrum',
    description:
      "XR One is an Orbit stack L3 with AnyTrust DA built by DeMoN Labs and partnered with Saltwater Games. It is designed to power unique PvP and AI-enhanced applications that spark user's imaginations through mechanics that reward risk-takers.",
    purposes: ['Gaming'],
    links: {
      websites: ['https://xrone.network/', 'https://saltwatergames.com/'],
      apps: [
        'https://xr-one.bridge.caldera.xyz/',
        'https://xrone.network/app/login',
      ],
      documentation: ['https://xr-one.gitbook.io/xr'],
      explorers: ['https://xr-one.calderaexplorer.xyz/'],
      socialMedia: [
        'https://x.com/XR_Foundation',
        'https://discord.com/invite/W4BdM6N8xb',
        'https://t.me/xrfoundation',
      ],
    },
  },
  chainConfig: {
    name: 'xrone',
    chainId: 273,
    apis: [
      {
        type: 'rpc',
        url: 'https://xr-one.calderachain.xyz/http',
        callsPerMinute: 1500,
      },
    ],
  },
  escrows: [
    {
      address: EthereumAddress('0xcf28946c814356A2A9df19c57937917f7Ef9D3Cf'), // bridge (native token: XR)
      sinceTimestamp: UnixTime(1733960896),
      tokens: ['ETH'],
      chain: 'arbitrum',
    },
    {
      address: EthereumAddress('0x3d450f3C54C3Fe0FA5ec1Eaf6Dd30F5eb88f5309'), // standardGW
      sinceTimestamp: UnixTime(1733960913),
      tokens: '*',
      chain: 'arbitrum',
    },
  ],
})
