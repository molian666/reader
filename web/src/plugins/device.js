import { getCache, setCache } from "./cache";

/**
 * 当前浏览器的稳定设备标识（保存在 localStorage）
 */
export function getDeviceId() {
  let id = getCache("reader_device_id");
  if (!id || typeof id !== "string") {
    id =
      "web-" +
      Date.now().toString(36) +
      "-" +
      Math.random()
        .toString(36)
        .slice(2, 8);
    setCache("reader_device_id", id);
  }
  return id;
}

/**
 * 根据 UA 生成可读的设备名，如 “Edge · Windows”
 */
export function getDeviceName() {
  const ua = (typeof navigator !== "undefined" && navigator.userAgent) || "";
  let browser = "浏览器";
  if (/Edg\//.test(ua)) {
    browser = "Edge";
  } else if (/OPR\//.test(ua)) {
    browser = "Opera";
  } else if (/Firefox\//.test(ua)) {
    browser = "Firefox";
  } else if (/Chrome\//.test(ua)) {
    browser = "Chrome";
  } else if (/Safari\//.test(ua)) {
    browser = "Safari";
  }
  let os = "";
  if (/Windows/.test(ua)) {
    os = "Windows";
  } else if (/Android/.test(ua)) {
    os = "Android";
  } else if (/iPhone|iPad|iPod/.test(ua)) {
    os = "iOS";
  } else if (/Mac OS X/.test(ua)) {
    os = "macOS";
  } else if (/Linux/.test(ua)) {
    os = "Linux";
  }
  return os ? browser + " · " + os : browser;
}
