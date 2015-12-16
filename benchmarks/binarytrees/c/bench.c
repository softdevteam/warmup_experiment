/* The Computer Language Shootout Benchmarks
   http://shootout.alioth.debian.org/

   contributed by Kevin Carson
   compilation:
       gcc -O3 -fomit-frame-pointer -funroll-loops -static binary-trees.c -lm
       icc -O3 -ip -unroll -static binary-trees.c -lm
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <err.h>

#define MIN_DEPTH 4
#define MAX_DEPTH 12
#define EXPECT_CKSUM -10914

typedef struct tn {
    struct tn*    left;
    struct tn*    right;
    long          item;
} treeNode;


treeNode* NewTreeNode(treeNode* left, treeNode* right, long item)
{
    treeNode*    new;

    new = (treeNode*)malloc(sizeof(treeNode));

    new->left = left;
    new->right = right;
    new->item = item;

    return new;
} /* NewTreeNode() */


long ItemCheck(treeNode* tree)
{
    if (tree->left == NULL)
        return tree->item;
    else
        return tree->item + ItemCheck(tree->left) - ItemCheck(tree->right);
} /* ItemCheck() */


treeNode* BottomUpTree(long item, unsigned depth)
{
    if (depth > 0)
        return NewTreeNode
        (
            BottomUpTree(2 * item - 1, depth - 1),
            BottomUpTree(2 * item, depth - 1),
            item
        );
    else
        return NewTreeNode(NULL, NULL, item);
} /* BottomUpTree() */


void DeleteTree(treeNode* tree)
{
    if (tree->left != NULL)
    {
        DeleteTree(tree->left);
        DeleteTree(tree->right);
    }

    free(tree);
} /* DeleteTree() */



int inner_rep(int minDepth, int maxDepth)
{
    unsigned   depth, stretchDepth;
    treeNode   *stretchTree, *longLivedTree, *tempTree;
    int32_t	check = 0;

    stretchDepth = maxDepth + 1;

    stretchTree = BottomUpTree(0, stretchDepth);
    check += ItemCheck(stretchTree);

    DeleteTree(stretchTree);

    longLivedTree = BottomUpTree(0, maxDepth);

    for (depth = minDepth; depth <= maxDepth; depth += 2)
    {
        long    i, iterations;

        iterations = pow(2, maxDepth - depth + minDepth);

        for (i = 1; i <= iterations; i++)
        {
            tempTree = BottomUpTree(i, depth);
            check += ItemCheck(tempTree);
            DeleteTree(tempTree);

            tempTree = BottomUpTree(-i, depth);
            check += ItemCheck(tempTree);
            DeleteTree(tempTree);
        } /* for(i = 1...) */

    } /* for(depth = minDepth...) */

    check += ItemCheck(longLivedTree);
    DeleteTree(longLivedTree);

    if (check != EXPECT_CKSUM) {
        errx(EXIT_FAILURE, "checksum failed: %u vs %u", check, EXPECT_CKSUM);
    }

    return 0;
} /* inner_rep() */

void run_iter(int n) {
    int i;

    for (i = 0; i < n; i++) {
        inner_rep(MIN_DEPTH, MAX_DEPTH);
    }
}
