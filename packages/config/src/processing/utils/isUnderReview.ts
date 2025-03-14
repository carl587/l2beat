import type { Bridge, ScalingProject } from '../../internalTypes'
import type { TableReadyValue } from '../../types'

// this function should be updated when new sections that can be under review are added
export function isUnderReview(project: ScalingProject | Bridge): boolean {
  return (
    !!project.isUnderReview ||
    (project.type === 'layer2' && project.stage.stage === 'UnderReview') ||
    !!project.technology.isUnderReview ||
    Object.values(project.riskView).some(
      (risk: TableReadyValue) => risk.sentiment === 'UnderReview',
    )
  )
}
