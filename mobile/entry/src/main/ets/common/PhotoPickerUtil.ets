import picker from '@ohos.file.picker'

export async function pickSingleImage(): Promise<string> {
  try {
    let options = new picker.PhotoSelectOptions()
    options.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
    options.maxSelectNumber = 1
    let photoPicker = new picker.PhotoViewPicker()
    let result = await photoPicker.select(options)
    if (result && result.photoUris.length > 0) {
      return result.photoUris[0]
    }
  } catch (err) {
    console.error('Pick image error', JSON.stringify(err))
  }
  return ''
}