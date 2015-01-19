#Command Line Usage:
```
perl decision-list.pl **Training Data**.txt **Test Data**.txt **Decision List**.txt > **Answers**.txt
```
# Description of Problem:
The goal of this project is to create a decision list for word sense disambiguation. We are focusing on the specific ambiguity:
```
        WordNet Case 15: telephone line, phone line, telephone circuit, subscriber line, line--- (a telephone connection)
       /
line =>
       \
        WordNet Case 22: line, product line, line of products, line of merchandise, business line, line of business -- (a particular kind of product or merchandise; "a nice line of shoes")
```

The method used to disambiguate these cases is outlined in David Yarowsky's paper: ["DECISION LISTS FOR LEXICAL AMBIGUITY RESOLUTION: Application to Accent Restoration in Spanish and French"](http://www.aclweb.org/anthology/P94-1013). There the author uses decision lists in order to properly apply accents in Spanish and French texts but many of the methods outlined are directly applicable to our problem.

We begin by analyzing the given training data using several collocational factors to determine how context correlates to word sense. Once we have recorded counts of how many times a certain factor is associated with each word sense, we sort all of the factors by their log-likelihood defined below:
```
                          P(Sense_1 | Collocation_i) 
log likelihood = Abs(Log( --------------------------))
                          P(Sense_2 | Collocation_i) 
```
This equation essentially tells us how correlated some ```Collocation_i``` is to one of the two word senses. For example, if there is no correlation, then the ```P(Accent_Pattern_1 | Collocation_i)``` and ```P(Accent_Pattern_2 | Collocation_i)``` should be pretty close to .5, thus we are taking the log of 1 which is 0. However if some ```Collocation_i``` is almost always associated with ```Accent_Pattern_1```, then the log likelihood would be very large.

Once we have this list of collocational factors sorted by their correlation with one of the two senses we can label word senses in some testing data set. For each testing sentence, we iterate through the decision list continuing until some collocational factor applies to the testing sentence and then apply the corresponding word sense to the testing sentence.
