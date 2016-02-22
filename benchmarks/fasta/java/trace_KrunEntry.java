import java.io.IOException;
class trace_KrunEntry implements BaseKrunEntry {
  public void run_iter(int param) {
      try {
          trace_fasta.runIter(param);
      } catch (IOException e) {
          System.out.println("fail!");
      }
  }
}
