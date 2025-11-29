/* eslint-disable eqeqeq */
import { DateTime } from 'luxon'
import Request from '#models/request'

interface DiseaseSummary {
  occurrences: number
  highestConfidence: number | null
  images: Set<number>
  treatments: Set<string>
}

const safeParseJson = (value: string | null | undefined): unknown => {
  if (!value) return null
  try {
    return JSON.parse(value)
  } catch {
    return null
  }
}

const formatConfidence = (value: number | null | undefined): string => {
  if (value == null || Number.isNaN(value)) {
    return 'unknown'
  }
  if (value <= 1) {
    return `${(value * 100).toFixed(0)}%`
  }
  return `${value.toFixed(2)}`
}

const pushNarrativeLine = (lines: string[], text: string): void => {
  lines.push(text.trim())
}

const recordDisease = (
  diseaseMap: Map<string, DiseaseSummary>,
  name: string | null | undefined,
  detail: Record<string, unknown> | null,
  imageIndex: number,
  narrativeLines: string[],
  confidences: number[]
): boolean => {
  if (!name) return false
  const trimmed = name.trim()
  if (!trimmed) return false

  const fragments: string[] = []
  const confidence =
    detail && typeof detail['confidence'] === 'number' ? (detail['confidence'] as number) : null
  if (confidence != null && Number.isFinite(confidence)) {
    confidences.push(confidence)
    fragments.push(`confidence ${formatConfidence(confidence)}`)
  }
  const treatment =
    detail && typeof detail['treatment'] === 'string' ? detail['treatment'].trim() : null
  if (treatment) {
    fragments.push(treatment)
  }

  const description = fragments.length > 0 ? ` (${fragments.join(', ')})` : ''
  pushNarrativeLine(narrativeLines, `- ${trimmed}${description}`)

  const stats = diseaseMap.get(trimmed) ?? {
    occurrences: 0,
    highestConfidence: null,
    images: new Set<number>(),
    treatments: new Set<string>(),
  }
  stats.occurrences += 1
  stats.images.add(imageIndex + 1)
  if (confidence != null && Number.isFinite(confidence)) {
    stats.highestConfidence =
      stats.highestConfidence == null ? confidence : Math.max(stats.highestConfidence, confidence)
  }
  if (treatment) {
    stats.treatments.add(treatment)
  }
  diseaseMap.set(trimmed, stats)
  return true
}

const buildNarrativeFromLeafs = (
  leafs: unknown,
  diseaseMap: Map<string, DiseaseSummary>,
  imageIndex: number,
  narrativeLines: string[],
  confidences: number[]
): boolean => {
  if (!Array.isArray(leafs)) return false
  let detected = false
  for (const leaf of leafs) {
    if (!leaf || typeof leaf !== 'object') continue
    const diseases = (leaf as Record<string, unknown>)['diseases']
    if (!diseases || typeof diseases !== 'object') continue
    for (const [name, payload] of Object.entries(diseases as Record<string, unknown>)) {
      const detail =
        payload && typeof payload === 'object' ? (payload as Record<string, unknown>) : null
      if (recordDisease(diseaseMap, name, detail, imageIndex, narrativeLines, confidences)) {
        detected = true
      }
    }
  }
  return detected
}

export const buildAiReport = (request: Request): string => {
  const images = request.images ?? []
  const diseaseMap = new Map<string, DiseaseSummary>()
  const confidences: number[] = []
  const recommendations = new Set<string>()
  const perImageNarratives: string[][] = []
  let diseasedImages = 0

  images.forEach((image, index) => {
    const narrative: string[] = []
    let detected = false

    const leafsData = safeParseJson(image.leafsData)
    if (buildNarrativeFromLeafs(leafsData, diseaseMap, index, narrative, confidences)) {
      detected = true
    }

    const diseasesJson = safeParseJson(image.diseasesJson)
    if (diseasesJson && typeof diseasesJson === 'object' && !Array.isArray(diseasesJson)) {
      for (const [name, payload] of Object.entries(diseasesJson as Record<string, unknown>)) {
        const detail =
          payload && typeof payload === 'object' ? (payload as Record<string, unknown>) : null
        if (recordDisease(diseaseMap, name, detail, index, narrative, confidences)) {
          detected = true
        }
      }
    }

    if (!detected && image.diseaseType) {
      const detail: Record<string, unknown> = {}
      if (image.confidence != null) {
        detail['confidence'] = image.confidence
      }
      if (image.treatmentPlan) {
        detail['treatment'] = image.treatmentPlan
      }
      if (recordDisease(diseaseMap, image.diseaseType, detail, index, narrative, confidences)) {
        detected = true
      }
    }

    if (image.treatmentPlan && image.treatmentPlan.trim().length > 0) {
      recommendations.add(`Treatment notes: ${image.treatmentPlan.trim()}`)
    }
    if (image.materials && image.materials.trim().length > 0) {
      recommendations.add(`Materials: ${image.materials.trim()}`)
    }
    if (image.services && image.services.trim().length > 0) {
      recommendations.add(`Services: ${image.services.trim()}`)
    }

    if (detected) {
      diseasedImages += 1
    } else if (narrative.length === 0) {
      pushNarrativeLine(narrative, '- Awaiting AI processing results for this image.')
    }

    perImageNarratives.push(narrative)
  })

  const totalImages = images.length
  const generatedAt = DateTime.now().toLocaleString(DateTime.DATETIME_MED_WITH_SECONDS)
  const farmName = request.farm?.name ?? `Farm ${request.farmId}`
  const sortedDiseases = Array.from(diseaseMap.entries()).sort(
    (a, b) => b[1].occurrences - a[1].occurrences
  )
  const topDiseases = sortedDiseases.slice(0, 3).map(([name]) => name)
  const minConfidence = confidences.length > 0 ? Math.min(...confidences) : null
  const maxConfidence = confidences.length > 0 ? Math.max(...confidences) : null

  const lines: string[] = []
  lines.push('# AI Diagnostic Report')
  lines.push('')
  lines.push(`**Request ID:** ${request.id}`)
  lines.push(`**Farm:** ${farmName}`)
  lines.push(`**Status:** ${request.status}`)
  lines.push(`**Generated:** ${generatedAt}`)
  lines.push('')
  lines.push('## Summary')
  lines.push('')
  lines.push(`- Images analyzed: ${totalImages}`)
  lines.push(`- Diseased images: ${diseasedImages}`)
  lines.push(
    `- Top diseases: ${
      topDiseases.length > 0 ? topDiseases.join(', ') : 'Awaiting additional AI predictions'
    }`
  )
  if (minConfidence != null && maxConfidence != null) {
    lines.push(
      `- Confidence range: ${formatConfidence(minConfidence)} → ${formatConfidence(maxConfidence)}`
    )
  } else {
    lines.push('- Confidence range: pending processed imagery')
  }
  lines.push('')
  lines.push('## Disease Highlights')
  lines.push('')

  if (sortedDiseases.length === 0) {
    lines.push(
      '- Disease highlights will appear once at least one image yields a confident detection.'
    )
  } else {
    for (const [name, stats] of sortedDiseases) {
      lines.push(`### ${name}`)
      lines.push('')
      lines.push(`- Appearances: ${stats.occurrences}`)
      const imageList = Array.from(stats.images)
        .sort((a, b) => a - b)
        .map((num) => `Image ${num}`)
        .join(', ')
      lines.push(`- Detected in images: ${imageList}`)
      if (stats.highestConfidence != null) {
        lines.push(`- Peak confidence: ${formatConfidence(stats.highestConfidence)}`)
      }
      if (stats.treatments.size > 0) {
        lines.push(`- Suggested treatment(s): ${Array.from(stats.treatments).join(' | ')}`)
      } else {
        lines.push('- Suggested treatment(s): awaiting agronomist review')
      }
      lines.push('')
    }
  }

  lines.push('## Image-level Findings')
  lines.push('')
  if (totalImages === 0) {
    lines.push(
      '- No images uploaded yet. Capture at least one photo to kick-start the AI analysis.'
    )
  } else {
    images.forEach((image, index) => {
      lines.push(`### Image ${index + 1} (${image.type})`)
      lines.push('')
      const details = perImageNarratives[index]
      if (details.length === 0) {
        lines.push('- Awaiting processing results for this image.')
      } else {
        details.forEach((line) => lines.push(line))
      }
      lines.push('')
    })
  }

  lines.push('## Recommendations')
  lines.push('')
  if (recommendations.size === 0) {
    lines.push(
      '- Continue regular scouting, optimize irrigation, and consult a technician before major interventions.'
    )
  } else {
    recommendations.forEach((note) => pushNarrativeLine(lines, `- ${note}`))
  }

  lines.push('')
  lines.push('## Diagnostic Body')
  lines.push('')
  lines.push(
    'Maintain this markdown as your working AI audit trail. Share it with agronomists or export it for compliance once you have processed all key images.'
  )

  return lines.join('\n')
}
