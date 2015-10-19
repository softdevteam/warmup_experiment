/*
 * The Computer Language Benchmarks Game
 * http://shootout.alioth.debian.org/
 *
 * modified by Mehmet D. AKIN
 * modified by Rikard Mustajarvi
 */

import java.io.IOException;
import java.io.OutputStream;

class ChecksumOutputStream extends OutputStream {
    /*
     * Dummy output stream that intercepts writes and updates a checksum
     */

    private long checksum = 0;

    public void reset() {
        checksum = 0;
    }

    public void write(byte[] b, int off, int len) {
        for (int i = 0; i < len; i++) {
            checksum += b[off + i];
        }
    }

    public long getChecksum() {
        return checksum;
    }

    /* OutputStreams supports (and requires us to implement)  writing one
     * byte at a time, however, our benchmark should never use this, as it
     * would cause the modulo computation to be performed too frequently, thus
     * giving Java an unfair disadvantage.
     */
    public void write(int b) {
        System.out.println("bad call");
        System.exit(1);
    }


}

class fasta {
    static void init() {};

   static final int IM = 139968;
   static final int IA = 3877;
   static final int IC = 29573;

   static final int LINE_LENGTH = 60;
   static final int BUFFER_SIZE = (LINE_LENGTH + 1)*1024; // add 1 for '\n'

   static final int SCALE = 10000;
   static final int EXPECT_CKSUM = 9611973;

    // Weighted selection from alphabet
    public static String ALU =
              "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"
            + "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"
            + "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"
            + "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"
            + "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"
            + "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"
            + "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA";

    private static final FloatProbFreq IUB = new FloatProbFreq(
          new byte[]{
                'a',  'c',  'g',  't',
                'B',  'D',  'H',  'K',
                'M',  'N',  'R',  'S',
                'V',  'W',  'Y'},
          new double[]{
                0.27, 0.12, 0.12, 0.27,
                0.02, 0.02, 0.02, 0.02,
                0.02, 0.02, 0.02, 0.02,
                0.02, 0.02, 0.02,
                }
          );

    private static final FloatProbFreq HOMO_SAPIENS = new FloatProbFreq(
          new byte[]{
                'a',
                'c',
                'g',
                't'},
          new double[]{
                0.3029549426680d,
                0.1979883004921d,
                0.1975473066391d,
                0.3015094502008d}
          );

   static final void makeRandomFasta(
         FloatProbFreq fpf, int nChars, OutputStream writer)
         throws IOException
   {
      final int LINE_LENGTH = fasta.LINE_LENGTH;
      final int BUFFER_SIZE = fasta.BUFFER_SIZE;
      byte[] buffer = new byte[BUFFER_SIZE];

      if (buffer.length % (LINE_LENGTH + 1) != 0) {
         throw new IllegalStateException(
            "buffer size must be a multiple of " +
            "line length (including line break)");
      }

      int bufferIndex = 0;
      while (nChars > 0) {
         int chunkSize;
         if (nChars >= LINE_LENGTH) {
            chunkSize = LINE_LENGTH;
         } else {
            chunkSize = nChars;
         }

         if (bufferIndex == BUFFER_SIZE) {
            writer.write(buffer, 0, bufferIndex);
            bufferIndex = 0;
         }

         bufferIndex = fpf
            .selectRandomIntoBuffer(buffer, bufferIndex, chunkSize);
         buffer[bufferIndex++] = '\n';

         nChars -= chunkSize;
      }

      writer.write(buffer, 0, bufferIndex);
   }

    static final void makeRepeatFasta(
          String alu,
          int nChars, OutputStream writer) throws IOException
    {
       final byte[] aluBytes = alu.getBytes();
       int aluIndex = 0;

       final int LINE_LENGTH = fasta.LINE_LENGTH;
       final int BUFFER_SIZE = fasta.BUFFER_SIZE;
       byte[] buffer = new byte[BUFFER_SIZE];

       if (buffer.length % (LINE_LENGTH + 1) != 0) {
          throw new IllegalStateException(
                "buffer size must be a multiple " +
                "of line length (including line break)");
       }

        int bufferIndex = 0;
        while (nChars > 0) {
           final int chunkSize;
           if (nChars >= LINE_LENGTH) {
              chunkSize = LINE_LENGTH;
         } else {
            chunkSize = nChars;
         }

           if (bufferIndex == BUFFER_SIZE) {
                writer.write(buffer, 0, bufferIndex);
                bufferIndex = 0;
           }

           for (int i = 0; i < chunkSize; i++) {
              if (aluIndex == aluBytes.length) {
                 aluIndex = 0;
              }

              buffer[bufferIndex++] = aluBytes[aluIndex++];
           }
           buffer[bufferIndex++] = '\n';

           nChars -= chunkSize;
        }

       writer.write(buffer, 0, bufferIndex);
    }

    public static void runIter(int n) throws IOException
    {
        ChecksumOutputStream out = new ChecksumOutputStream();

        for (int i = 0; i < n; i++) {
            makeRepeatFasta(ALU, SCALE * 2, out);
            makeRandomFasta(IUB, SCALE * 3, out);
            makeRandomFasta(HOMO_SAPIENS, SCALE * 5, out);

            long ck = out.getChecksum();
            if (ck != EXPECT_CKSUM) {
                System.out.println("Bad checksum: " + ck + " vs " + EXPECT_CKSUM);
                System.exit(1);
            }

            FloatProbFreq.reset_random();
            out.reset();
        }
        out.close();
    }

    public static final class FloatProbFreq {
       static final int INITIAL_STATE = 42;
       static int last = INITIAL_STATE;
       final byte[] chars;
       final float[] probs;

       public FloatProbFreq(byte[] chars, double[] probs) {
          this.chars = chars;
          this.probs = new float[probs.length];
          for (int i = 0; i < probs.length; i++) {
             this.probs[i] = (float)probs[i];
          }
          makeCumulative();
       }

       public static void reset_random() {
           last = INITIAL_STATE;
       }

       private final void makeCumulative() {
            double cp = 0.0;
            for (int i = 0; i < probs.length; i++) {
                cp += probs[i];
                probs[i] = (float)cp;
            }
        }

       public final int selectRandomIntoBuffer(
             byte[] buffer, int bufferIndex, final int nRandom) {
          final byte[] chars = this.chars;
          final float[] probs = this.probs;
          final int len = probs.length;

          outer:
          for (int rIndex = 0; rIndex < nRandom; rIndex++) {
             final float r = random(1.0f);
                for (int i = 0; i < len; i++) {
                 if (r < probs[i]) {
                    buffer[bufferIndex++] = chars[i];
                    continue outer;
                 }
              }

                buffer[bufferIndex++] = chars[len-1];
          }

            return bufferIndex;
       }

        // pseudo-random number generator
        public static final float random(final float max) {
           final float oneOverIM = (1.0f/ IM);
            last = (last * IA + IC) % IM;
            return max * last * oneOverIM;
        }
    }
}
