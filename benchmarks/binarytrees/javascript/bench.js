/* The Computer Language Benchmarks Game
   http://benchmarksgame.alioth.debian.org/
   contributed by Isaac Gouy */

var MIN_DEPTH = 4;
var MAX_DEPTH = 12;
var EXPECT_CKSUM = -10914

function TreeNode(left,right,item){
   this.left = left;
   this.right = right;
   this.item = item;
}

TreeNode.prototype.itemCheck = function(){
   if (this.left==null) return this.item;
   else return this.item + this.left.itemCheck() - this.right.itemCheck();
}

function bottomUpTree(item,depth){
   if (depth>0){
      return new TreeNode(
          bottomUpTree(2*item-1, depth-1)
         ,bottomUpTree(2*item, depth-1)
         ,item
      );
   }
   else {
      return new TreeNode(null,null,item);
   }
}


function inner_iter(minDepth, maxDepth) {
    var check = 0;
    var stretchDepth = maxDepth + 1;

    check = bottomUpTree(0,stretchDepth).itemCheck();

    var longLivedTree = bottomUpTree(0,maxDepth);
    for (var depth=minDepth; depth<=maxDepth; depth+=2){
       var iterations = 1 << (maxDepth - depth + minDepth);

       for (var i=1; i<=iterations; i++){
          check += bottomUpTree(i,depth).itemCheck();
          check += bottomUpTree(-i,depth).itemCheck();
       }
    }

    check += longLivedTree.itemCheck();

    if (check != EXPECT_CKSUM) {
        print("bad checksum: " + checksum + " vs " + EXPECT_CKSUM);
        quit(1);
    }
}

function run_iter(n) {
    var i;
    for (i = 0; i < n; i++) {
        inner_iter(MIN_DEPTH, MAX_DEPTH);
    }
}
