
# Usage:
#./graph.sh derivationTree.dot

echo $1
dot -Tpng $1 -O
xdg-open $1.png&
