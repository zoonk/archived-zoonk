/**
 * S3 uploader
 *
 * Allows to upload files to a S3-compatible storage server.
 *
 * @param {*} entries
 * @param {*} onViewError
 */
export default function (entries, onViewError) {
  entries.forEach((entry) => {
    let { url } = entry.meta;
    let xhr = new XMLHttpRequest();

    onViewError(() => xhr.abort());

    xhr.onload = () => (xhr.status >= 200 && xhr.status < 300 ? entry.progress(100) : entry.error());

    xhr.onerror = () => entry.error();
    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) {
        let percent = Math.round((event.loaded / event.total) * 100);
        if (percent < 100) {
          entry.progress(percent);
        }
      }
    });

    xhr.open("PUT", url, true);
    xhr.setRequestHeader("credentials", "same-origin parameter");
    xhr.send(entry.file);
  });
}
