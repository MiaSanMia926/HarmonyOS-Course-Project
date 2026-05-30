import fs from '@ohos.file.fs'
import common from '@ohos.app.ability.common'
import util from '@ohos.util'
import picker from '@ohos.file.picker'

class FileService {
  private context: common.UIAbilityContext | null = null

  init(context: common.UIAbilityContext): void {
    this.context = context
  }

  async saveImageToSandbox(uri: string): Promise<string> {
    if (!this.context) return uri
    const fileName = `img_${Date.now()}.jpg`
    const sandboxPath = `${this.context.filesDir}/${fileName}`
    try {
      const srcFile = fs.openSync(uri, fs.OpenMode.READ_ONLY)
      const destFile = fs.openSync(sandboxPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      const buf = new ArrayBuffer(4096)
      let readLen = fs.readSync(srcFile.fd, buf)
      while (readLen > 0) {
        fs.writeSync(destFile.fd, buf, { length: readLen })
        readLen = fs.readSync(srcFile.fd, buf)
      }
      fs.closeSync(srcFile)
      fs.closeSync(destFile)
      return sandboxPath
    } catch (e) {
      return uri
    }
  }

  async readImageAsBase64(path: string): Promise<string> {
    try {
      let file = fs.openSync(path, fs.OpenMode.READ_ONLY)
      let stat = fs.statSync(file.fd)
      let buf = new ArrayBuffer(stat.size)
      fs.readSync(file.fd, buf)
      fs.closeSync(file)
      let helper = new util.Base64Helper()
      return helper.encodeToStringSync(new Uint8Array(buf))
    } catch (e) {
      return ''
    }
  }

  async deleteImage(path: string): Promise<void> {
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path)
      }
    } catch (e) {}
  }

  async exportLogsToText(content: string): Promise<string> {
    try {
      let documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.newFileNames = [`PlantDiary_${Date.now()}.txt`];
      documentSaveOptions.fileSuffixChoices = ['.txt'];
      
      let documentViewPicker = new picker.DocumentViewPicker();
      let documentSaveResult = await documentViewPicker.save(documentSaveOptions);
      
      if (documentSaveResult && documentSaveResult.length > 0) {
        let uri = documentSaveResult[0];
        let file = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.writeSync(file.fd, content);
        fs.closeSync(file);
        return uri;
      }
      return '';
    } catch (e) {
      console.error('export error:', e);
      return '';
    }
  }
}

export const fileService = new FileService()