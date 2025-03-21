import { UnixTime } from '@l2beat/shared-pure'
import type { ScalingProject } from '../../internalTypes'
import { upcomingL2 } from '../../templates/upcoming'

export const openzk: ScalingProject = upcomingL2({
  id: 'openzk',
  capability: 'universal',
  addedAt: UnixTime(1739874850),
  display: {
    name: 'OpenZK',
    slug: 'openzk',
    description:
      'OpenZK is the first Layer 2 solution on ZK rollup technology to unite native ETH staking, liquid restaking, and stablecoin staking in one seamless platform.',
    purposes: ['Universal'],
    category: 'ZK Rollup',
    stack: 'ZK Stack',
    links: {
      websites: ['https://openzk.net/'],
      apps: ['https://portal.openzk.net/bridge'],
      documentation: ['https://docs.openzk.net/'],
      explorers: ['https://explorer.openzk.net/'],
      repositories: [],
      socialMedia: [
        'https://x.com/OpenZkNetwork',
        'https://linkedin.com/company/openzk',
        'https://t.me/OpenZkNetwork',
      ],
    },
  },
})
