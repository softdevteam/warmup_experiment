import java.io.IOException;
class KrunEntry {
  public static void run_iter(int param) {
      try {
          fasta.runIter(param);
      } catch (IOException e) {
          System.out.println("fail!");
      }
  }
}
