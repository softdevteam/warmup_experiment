/* The Great Computer Language Shootout
   http://shootout.alioth.debian.org/

   contributed by Jarkko Miettinen
*/

public class binarytrees {
    static void init() {};

	private static final int MIN_DEPTH = 4;
	private static final int MAX_DEPTH = 12;
	private static final long EXPECT_CKSUM = -10914;
	private static long MOD;
	private static int check = 0;


	public static void run(int n) {
		for (int i = 0; i < n; i++) {
			check = 0;
			inner_iter(MIN_DEPTH, MAX_DEPTH);
		}
	}

	public static void inner_iter(int minDepth, int maxDepth) {
		int stretchDepth = maxDepth + 1;

		check += TreeNode.bottomUpTree(0,stretchDepth).itemCheck();

		TreeNode longLivedTree = TreeNode.bottomUpTree(0,maxDepth);

		for (int depth=minDepth; depth<=maxDepth; depth+=2){
			int iterations = 1 << (maxDepth - depth + minDepth);

			for (int i=1; i<=iterations; i++){
				check += (TreeNode.bottomUpTree(i,depth)).itemCheck();
				check += (TreeNode.bottomUpTree(-i,depth)).itemCheck();
			}
		}

		check += longLivedTree.itemCheck();

		if (check != EXPECT_CKSUM) {
			System.out.println("bad check: " + check  + " vs " + EXPECT_CKSUM);
			System.exit(1);
		}
	}


	private static class TreeNode
	{
		private TreeNode left, right;
		private int item;

		TreeNode(int item){
			this.item = item;
		}

		private static TreeNode bottomUpTree(int item, int depth){
			if (depth>0){
				return new TreeNode(
						bottomUpTree(2*item-1, depth-1)
						, bottomUpTree(2*item, depth-1)
						, item
				);
			}
			else {
				return new TreeNode(item);
			}
		}

		TreeNode(TreeNode left, TreeNode right, int item){
			this.left = left;
			this.right = right;
			this.item = item;
		}

		private int itemCheck(){
			// if necessary deallocate here
			if (left==null) return item;
			else return item + left.itemCheck() - right.itemCheck();
		}
	}
}
