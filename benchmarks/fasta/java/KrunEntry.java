import java.io.IOException;
class KrunEntry implements BaseKrunEntry {
  public void run_iter(int param) {
      try {
          fasta.runIter(param);
      } catch (IOException e) {
          System.out.println("fail!");
      }
  }
}
