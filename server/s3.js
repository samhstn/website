import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3'
import { Readable } from 'stream'

const bucketName = 'my-bucket-name'

class S3 {
  constructor ({ bucketName }) {
    this.s3Client = new S3Client()
    this.bucketName = bucketName
  }

  async stream (key, res) {
    try {
      const command = new GetObjectCommand({
        Bucket: this.bucketName,
        Key: key
      })

      const s3Response = await this.s3Client.send(command)

      res.setHeader('Content-Type', s3Response.ContentType || 'application/octet-stream')
      res.setHeader('Content-Length', s3Response.ContentLength)

      if (s3Response.Body instanceof Readable) {
        s3Response.Body.pipe(res)
      } else {
        throw new Error('Unexpected response body type')
      }
    } catch (error) {
      console.error('Error streaming object from S3:', error)
      res.status(500).send('Error fetching file from S3')
    }
  }
}

export default S3
