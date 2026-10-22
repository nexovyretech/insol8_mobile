import {
  S3Client,
  ListObjectsV2Command,
  HeadObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({});
const BUCKET = process.env.BUCKET;
const PREFIX = 'builds/';
const MAX_BUILDS = 10;
const LINK_TTL_SECONDS = 15 * 60;

// GET /builds  ->  { builds: [{ name, version, run, commit, notes, uploaded, sizeBytes, url }] }
// Only reachable with a valid Cognito token (the API's JWT authorizer rejects everything else).
export const handler = async () => {
  const listed = await s3.send(
    new ListObjectsV2Command({ Bucket: BUCKET, Prefix: PREFIX }),
  );

  const newest = (listed.Contents ?? [])
    .filter((o) => o.Key?.endsWith('.apk'))
    .sort((a, b) => b.LastModified - a.LastModified)
    .slice(0, MAX_BUILDS);

  const builds = await Promise.all(
    newest.map(async (o) => {
      const name = o.Key.split('/').pop();
      const head = await s3.send(new HeadObjectCommand({ Bucket: BUCKET, Key: o.Key }));
      const meta = head.Metadata ?? {};
      const url = await getSignedUrl(
        s3,
        new GetObjectCommand({
          Bucket: BUCKET,
          Key: o.Key,
          ResponseContentDisposition: `attachment; filename="${name}"`,
          ResponseContentType: 'application/vnd.android.package-archive',
        }),
        { expiresIn: LINK_TTL_SECONDS },
      );
      return {
        name,
        version: meta.version ?? '',
        run: meta.run ?? '',
        commit: meta.commit ?? '',
        notes: meta.notes ?? '',
        uploaded: o.LastModified.toISOString(),
        sizeBytes: o.Size,
        url,
      };
    }),
  );

  return {
    statusCode: 200,
    headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
    body: JSON.stringify({ builds, linkValidSeconds: LINK_TTL_SECONDS }),
  };
};
