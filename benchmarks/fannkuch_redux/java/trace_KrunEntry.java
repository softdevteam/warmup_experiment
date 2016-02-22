
class trace_KrunEntry implements BaseKrunEntry {
  public void run_iter(int param) {
      System.out.println("public void run_iter(int param) {");
      trace_fannkuchredux.runIter(param);
  }
}
