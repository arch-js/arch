now=$(date +"%Y-%m-%d")

npm install -g tidy-markdown

# Checkout website
git clone git@github.com:arch-js/arch-js.github.io.git ../arch-js.github.io

# Copy docs to website
for file in ./docs/*
do
  echo $(basename "$file")

  # Run through prettifier
  tidy-markdown < $file > temp

  # Add frontmatter and copy to website
  echo $'---\n\n---\n' | cat - temp > ../arch-js.github.io/docs/$(basename "$file")
done

rm temp

echo $now
echo "Doc updates $now"

# Commit and push / submit pull request
cd ../arch-js.github.io
git add .
git commit -m "Doc updates $now"
