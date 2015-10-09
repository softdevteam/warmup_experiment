
class KrunEntry implements BaseKrunEntry {
  static { binarytrees.init(); } // force class to be loaded

  public void run_iter(int param) {
      binarytrees.run(param);
  }
}
