import { env } from '../config/env.js';

export interface Exercise3dMedia {
  exerciseSlug: string;
  animation3dGlbUrl: string;
  animation3dUsdzUrl: string;
  videoStreamUrl: string;
  thumbnailUrl: string;
  storageProvider: 'cloudflare_r2';
  bucket: string;
  cdnCached: boolean;
  fps: number;
  resolution: string;
  meshPolycount: number;
  rigBonesCount: number;
}

export class StorageService {
  /**
   * Generates CDN and object storage links for 3D human biomechanical models and 4K exercise demonstrations.
   */
  static getExerciseMediaAssets(exerciseNameOrSlug: string): Exercise3dMedia {
    const slug = exerciseNameOrSlug
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const baseUrl = env.R2_PUBLIC_URL.replace(/\/$/, '');

    return {
      exerciseSlug: slug,
      animation3dGlbUrl: `${baseUrl}/exercises/3d/${slug}-human-3d.glb`,
      animation3dUsdzUrl: `${baseUrl}/exercises/3d/${slug}-human-3d.usdz`,
      videoStreamUrl: `${baseUrl}/exercises/video/${slug}-4k.mp4`,
      thumbnailUrl: `${baseUrl}/exercises/thumbs/${slug}-poster.webp`,
      storageProvider: 'cloudflare_r2',
      bucket: env.R2_BUCKET_NAME,
      cdnCached: true,
      fps: 60,
      resolution: '3840x2160',
      meshPolycount: 42500,
      rigBonesCount: 68,
    };
  }

  /**
   * Generates mock presigned R2 upload parameters for uploading new 3D model files.
   */
  static generatePresignedUploadUrl(filename: string, contentType: string) {
    const key = `exercises/3d/${Date.now()}-${filename}`;
    return {
      uploadUrl: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com/${env.R2_BUCKET_NAME}/${key}`,
      publicUrl: `${env.R2_PUBLIC_URL}/${key}`,
      key,
      bucket: env.R2_BUCKET_NAME,
      headers: {
        'Content-Type': contentType,
        'x-amz-acl': 'public-read',
      },
      expiresInSeconds: 3600,
    };
  }
}
