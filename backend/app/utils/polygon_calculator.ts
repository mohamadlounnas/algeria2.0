/**
 * Calculate area of polygon in square meters using shoelace formula
 * Adapted from the Flutter implementation
 */
export function calculatePolygonArea(
  polygon: Array<{ latitude: number; longitude: number }>
): number {
  if (polygon.length < 3) return 0

  const earthRadiusM = 6371000.0 // Earth radius in meters

  let area = 0
  for (let i = 0; i < polygon.length; i++) {
    const j = (i + 1) % polygon.length

    const lat1 = (polygon[i].latitude * Math.PI) / 180
    const lat2 = (polygon[j].latitude * Math.PI) / 180
    const lon1 = (polygon[i].longitude * Math.PI) / 180
    const lon2 = (polygon[j].longitude * Math.PI) / 180

    area += (lon2 - lon1) * (2 + Math.sin(lat1) + Math.sin(lat2)) * earthRadiusM * earthRadiusM
  }

  return Math.abs(area) / 2.0
}
