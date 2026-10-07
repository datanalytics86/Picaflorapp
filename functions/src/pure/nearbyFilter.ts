import { isAdult } from './age';
import { activityBucket, LOCATION_MAX_AGE_MS, type ActivityBucket } from './activity';
import { distanceBucket, type DistanceBucket } from './distance';

export interface NearbyCandidate {
  uid: string;
  distanceMeters: number;
  isVisible: boolean;
  locationUpdatedAt: Date | null;
  birthDate: Date | null;
  blockedEitherWay: boolean;
  hasWave: boolean;
  lastActiveAt: Date | null;
}

export interface NearbyPerson {
  uid: string;
  distanceBucket: DistanceBucket;
  activityBucket: ActivityBucket;
}

/**
 * Incognito (isVisible == false) is hidden unless a wave already exists
 * between the two people. Missing birth dates and minors are always hidden.
 */
export function filterNearbyPeople(args: {
  callerUid: string;
  radiusMeters: number;
  now: Date;
  candidates: NearbyCandidate[];
}): NearbyPerson[] {
  const people: Array<NearbyPerson & { distanceMeters: number }> = [];
  for (const candidate of args.candidates) {
    if (candidate.uid === args.callerUid) continue;
    if (candidate.blockedEitherWay) continue;
    if (!(candidate.distanceMeters <= args.radiusMeters)) continue;
    if (!candidate.locationUpdatedAt) continue;
    const locationAge = args.now.getTime() - candidate.locationUpdatedAt.getTime();
    if (locationAge > LOCATION_MAX_AGE_MS) continue;
    if (!candidate.birthDate || !isAdult(candidate.birthDate, args.now)) continue;
    if (!candidate.isVisible && !candidate.hasWave) continue;
    if (!candidate.lastActiveAt) continue;
    const activity = activityBucket(candidate.lastActiveAt, args.now);
    if (!activity) continue;
    people.push({
      uid: candidate.uid,
      distanceMeters: candidate.distanceMeters,
      distanceBucket: distanceBucket(candidate.distanceMeters),
      activityBucket: activity,
    });
  }
  people.sort((a, b) => a.distanceMeters - b.distanceMeters || a.uid.localeCompare(b.uid));
  return people.map(({ uid, distanceBucket: bucket, activityBucket: activity }) => ({
    uid,
    distanceBucket: bucket,
    activityBucket: activity,
  }));
}
