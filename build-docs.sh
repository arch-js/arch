npm install -g tidy-markdown

# Checkout website
git clone git@github.com:arch-js/arch-js.github.io.git

echo $PWD
# Copy Docs
# Run through beautifier
for file in ./docs/*
do
  tidy-markdown < $file > ../arch-js.github.io/docs/$file.md
done


# Add frontmatter

# Copy to website

# Commit and push / submit pull request
