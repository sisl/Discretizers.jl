# disc_MODL.jl

disc_MODL.jl returns the supervised discretization of continuous attributes based on their class values, which are discrete. For each discretization, we have a score for it, which is proportional to the inverse of likehood:

$$
P(Model\,|\, Data)  \propto P(Data\,|\, Model) P(Model)
$$

The discretization corresponding to the minimal score, i.e., maximal likehood, is the one.

In the following, we first demonstrate the concept by example, then we show the formal mathematical expression and the three algorithms behind disc_MODL.jl.


** Example and Demonstration **

In car-driving system, we have data as follows: 

![Example of data](fig1.png =400x250)

We want to discretize the continuous attribute Speed. How do we score each discretization? Notice that, after discretization, we could obtain the conditional probability tables as: 

Before discretization,

![Example of data](fig2.jpg =350x250)

After discretization, we get bins and the conditional probability tables such as:

![Example of data](fig3.jpg =350x250)

To score the discretization, $P(Data\,|\, Model)$ could be computed by these conditional probability tables and $P(Model)$ is computed by the prior of distribution. By multiplying these two terms and taking the inverse, we obtain the score of this discretization.

** Mathematical Expression of The Objective Function **

Before writing down the equations, we define variables: $n$ as number of instances. $J$ as number of class values. $I$ as number of intervals of discretization of the continuous attribute. $n_i$ as number of instances in the interval $i$. $n_{ij}$ as the number of instances of class $j$ in the interval $i$. Then the score of discretization could be represented by these variables.

For convenice, in the algorithm we compute the score as $log(1/P(Model)) + log(1/P(Data\,|\, Model))$. The first part, as mentioned above, it is based on the three stage prior of distribution:

- the number of intervals $I$ is uniformly distributed between $1$ and $n$.
- for a given number of intervals $I$, every division of the string to discretize into $I$ intervals is equiprobable.
- for a given interval, every distribution of class values in the interval is equiprobable
- the distributions of the class values in each interval are independent from each other

Then the first part of score could be written as:

$$
log(n) + log{{n+I-1}\choose{I-1}} + \sum_{i=1}^{I}{log{{n_i+J-1}\choose{J-1}}}
$$

The second part of score is simply

$$
\sum_{i=1}^{I} log{ { {n_i !}\choose{{n_{i,1}!}{n_{i,2}!}{n_{i,3}!}...}}}
$$

In summary, the score of discretization is
$$
log(n) + log{{n+I-1}\choose{I-1}} + \sum_{i=1}^{I}{log{{n_i+J-1}\choose{J-1}}} + \sum_{i=1}^{I} log{ { {n_i !}\choose{{n_{i,1}!}{n_{i,2}!}{n_{i,3}!}...}}}
$$

** Three Algorithms behind disc_MODL.jl **

