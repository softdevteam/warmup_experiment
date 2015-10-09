import java.io.IOException;
class KrunEntry implements BaseKrunEntry {
  static { fasta.init(); } // force class to be loaded

  public void run_iter(int param) {
      try {
          fasta.runIter(param);
      } catch (IOException e) {
          System.out.println("fail!");
      }
  }
}
