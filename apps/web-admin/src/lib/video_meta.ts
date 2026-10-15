/** Reads a local video's length and grabs a frame as a JPEG thumbnail, all in
 * the browser — so the admin never has to make a separate cover image. The
 * frame is re-encoded through a canvas (clean JPEG, max 960px wide). Returns
 * a null blob if the browser can't decode the video (the upload still works;
 * the app falls back to a plain card). */
export async function readVideoMeta(file: File): Promise<{ durationSec: number | null; thumbnail: Blob | null }> {
  const url = URL.createObjectURL(file);
  const video = document.createElement("video");
  video.muted = true;
  video.playsInline = true;
  video.preload = "metadata";
  video.src = url;

  const finish = <T,>(value: T): T => {
    URL.revokeObjectURL(url);
    video.removeAttribute("src");
    video.load();
    return value;
  };

  try {
    await new Promise<void>((resolve, reject) => {
      video.onloadedmetadata = () => resolve();
      video.onerror = () => reject(new Error("unreadable"));
      setTimeout(() => reject(new Error("timeout")), 10_000);
    });
    const duration = Number.isFinite(video.duration) ? video.duration : null;

    // Seek a little in — frame 0 is often black.
    video.currentTime = Math.min(1, (duration ?? 2) / 2);
    await new Promise<void>((resolve, reject) => {
      video.onseeked = () => resolve();
      video.onerror = () => reject(new Error("unreadable"));
      setTimeout(() => reject(new Error("timeout")), 10_000);
    });

    const scale = Math.min(1, 960 / video.videoWidth);
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(64, Math.round(video.videoWidth * scale));
    canvas.height = Math.max(64, Math.round(video.videoHeight * scale));
    canvas.getContext("2d")?.drawImage(video, 0, 0, canvas.width, canvas.height);
    const thumbnail = await new Promise<Blob | null>((res) => canvas.toBlob(res, "image/jpeg", 0.8));
    return finish({ durationSec: duration && duration > 0 ? Math.round(duration) : null, thumbnail });
  } catch {
    return finish({ durationSec: null, thumbnail: null });
  }
}
