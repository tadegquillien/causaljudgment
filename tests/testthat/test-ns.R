library(testthat)

test_that("NS handles conjunctive and disjunctive structures", {
  
  pa <- .1
  pb <- .9
  
  conjModel <- list(
    e = "a&b",
    a = pa,
    b = pb
  )
  
  disjModel <- list(
    e = "a|b",
    a = pa,
    b = pb
  )
  
  actual_world <- list(
    e = 1,
    a = 1,
    b = 1
  )
  
  # Conjunctive structure
  expect_equal(
    compute_judgment(
      "a", "e", conjModel, actual_world, "ns", 0
    ),
    0.99,
    tolerance = 1e-7
  )
  
  expect_equal(
    compute_judgment(
      "b", "e", conjModel, actual_world, "ns", 0
    ),
    0.19,
    tolerance = 1e-7
  )
  
  # Disjunctive structure
  expect_equal(
    compute_judgment(
      "a", "e", disjModel, actual_world, "ns", 0
    ),
    0.1,
    tolerance = 1e-7
  )
  
  expect_equal(
    compute_judgment(
      "b", "e", disjModel, actual_world, "ns", 0
    ),
    0.9,
    tolerance = 1e-7
  )
})

test_that("NS doesn't judge that E causes C", {
  
  cm <- list(
    wet='rain',
    rain='cloud',
    cloud=.5
  )
  
  actual_world <- list(
    wet = 1,
    rain = 1,
    cloud = 1
  )
  
  expect_equal(
    compute_judgment(
      "wet", "rain", cm, actual_world, "ns", 0
    ),
    0,
    tolerance = 1e-7
  )
  
  expect_equal(
    compute_judgment(
      "rain", "wet", cm, actual_world, "ns", 0
    ),
    1,
    tolerance = 1e-7
  )
  
})

test_that("NS doesn't judge that ¬E causes ¬C", {
  
  cm <- list(
    wet='rain',
    rain='cloud',
    cloud=.5
  )
  
  actual_world <- list(
    wet = 0,
    rain = 0,
    cloud = 0
  )
  
  expect_equal(
    compute_judgment(
      "wet", "rain", cm, actual_world, "ns", 0
    ),
    0,
    tolerance = 1e-7
  )
  
  expect_equal(
    compute_judgment(
      "rain", "wet", cm, actual_world, "ns", 0
    ),
    1,
    tolerance = 1e-7
  )

})




