/* The Computer Language Shootout Benchmarks
   http://shootout.alioth.debian.org/

   contributed by Kevin Carson
   compilation:
       gcc -O3 -fomit-frame-pointer -funroll-loops -static binary-trees.c -lm
       icc -O3 -ip -unroll -static binary-trees.c -lm
*/

#include <malloc.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <err.h>

#define MIN_DEPTH 4
#define MAX_DEPTH 12
#define EXPECT_CKSUM 4294956382

static u_int32_t checksum = 0;

typedef struct tn {
    struct tn*    left;
    struct tn*    right;
    long          item;
} treeNode;


treeNode* NewTreeNode(treeNode* left, treeNode* right, long item)
{
    printf("treeNode* NewTreeNode(treeNode* left, treeNode* right, long item)\n");
    treeNode*    new;

    new = (treeNode*)malloc(sizeof(treeNode));

    new->left = left;
    new->right = right;
    new->item = item;

    return new;
} /* NewTreeNode() */


long ItemCheck(treeNode* tree)
{
    printf("long ItemCheck(treeNode* tree)\n");
    if (tree->left == NULL)
        return tree->item;
    else
        return tree->item + ItemCheck(tree->left) - ItemCheck(tree->right);
} /* ItemCheck() */


treeNode* BottomUpTree(long item, unsigned depth)
{
    printf("treeNode* BottomUpTree(long item, unsigned depth)\n");
    if (depth > 0)
    {
        printf("if (depth > 0)\n");
        return NewTreeNode
        (
            BottomUpTree(2 * item - 1, depth - 1),
            BottomUpTree(2 * item, depth - 1),
            item
        );
    }
    else
    {
        printf("else\n");
        return NewTreeNode(NULL, NULL, item);
    }
} /* BottomUpTree() */


void DeleteTree(treeNode* tree)
{
    printf("void DeleteTree(treeNode* tree)\n");
    if (tree->left != NULL)
    {
        printf("if (tree->left != NULL)\n");
        DeleteTree(tree->left);
        DeleteTree(tree->right);
    }

    free(tree);
} /* DeleteTree() */



int inner_rep(int minDepth, int maxDepth)
{
    printf("int inner_rep(int minDepth, int maxDepth)\n");
    unsigned   depth, stretchDepth;
    treeNode   *stretchTree, *longLivedTree, *tempTree;

    stretchDepth = maxDepth + 1;

    stretchTree = BottomUpTree(0, stretchDepth);
    checksum += ItemCheck(stretchTree);

    DeleteTree(stretchTree);

    longLivedTree = BottomUpTree(0, maxDepth);

    for (depth = minDepth; depth <= maxDepth; depth += 2)
    {
        printf("for (depth = minDepth; depth <= maxDepth; depth += 2)\n");
        long    i, iterations, check;

        iterations = pow(2, maxDepth - depth + minDepth);

        check = 0;

        for (i = 1; i <= iterations; i++)
        {
            printf("for (i = 1; i <= iterations; i++)\n");
            tempTree = BottomUpTree(i, depth);
            check += ItemCheck(tempTree);
            DeleteTree(tempTree);

            tempTree = BottomUpTree(-i, depth);
            check += ItemCheck(tempTree);
            DeleteTree(tempTree);
        } /* for(i = 1...) */

        checksum += check;

    } /* for(depth = minDepth...) */

    checksum += ItemCheck(longLivedTree);
    DeleteTree(longLivedTree);

    if (checksum != EXPECT_CKSUM)
    {
        printf("if (checksum != EXPECT_CKSUM)\n");
        errx(EXIT_FAILURE, "checksum failed: %u vs %lu", checksum, EXPECT_CKSUM);
    }

    return 0;
} /* inner_rep() */

void run_iter(int n)
{
    printf("void run_iter(int n)\n");
    int i;

    for (i = 0; i < n; i++)
    {
        printf("for (i = 0; i < n; i++)\n");
        inner_rep(MIN_DEPTH, MAX_DEPTH);
        checksum = 0;
    }
}
