// Desc: base64 to int32array
export const base64ToInt32Array = (base64) => {
  const decodedBinaryString = atob(base64)
  const byteArray = new Uint8Array(decodedBinaryString.length)

  for (let i = 0; i < decodedBinaryString.length; i++) {
    byteArray[i] = decodedBinaryString.charCodeAt(i)
  }

  // 2. Convert the bytes into Int32 values
  return new Int32Array(byteArray.buffer)
}
