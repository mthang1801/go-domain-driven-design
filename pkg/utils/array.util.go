package utils

func Filter[T any](slice []T, predicate func(T) bool) []T {
	result := make([]T, 0)
	for _, item := range slice {
		if predicate(item) {
			result = append(result, item)
		}
	}
	return result
}

func Map[T any, R any](slice []T, mapper func(T) R) []R {
	result := make([]R, len(slice))
	for i, ele := range slice {
		result[i] = mapper(ele)
	}
	return result
}

func Reduce[T any, R any](slice []T, reducer func(R, T) R, initial R) R {
	result := initial
	for _, ele := range slice {
		result = reducer(result, ele)
	}
	return result
}

func Some[T any](slice []T, predicate func(T) bool) bool {
	for _, ele := range slice {
		if predicate(ele) {
			return true
		}
	}
	return false
}

func Every[T any](slice []T, predicate func(T) bool) bool {
	for _, ele := range slice {
		if !predicate(ele) {
			return false
		}
	}
	return true
}

func Find[T any](slice []T, predicate func(T) bool) (T, bool) {
	for _, ele := range slice {
		if predicate(ele) {
			return ele, true
		}
	}
	var zero T
	return zero, false
}

func FindIndex[T any](slice []T, predicate func(T) bool) int {
	for idx, ele := range slice {
		if predicate(ele) {
			return idx
		}
	}
	return -1
}

func Includes[T comparable](slice []T, value T) bool {
	for _, ele := range slice {
		if ele == value {
			return true
		}
	}
	return false
}

func Flat[T any](slice [][]T) []T {
	result := make([]T, 0)
	for _, subSlice := range slice {
		result = append(result, subSlice...)
	}
	return result
}

func FlatMap[T any, R any](slice []T, mapper func(T) []R) []R {
	result := make([]R, 0)
	for _, ele := range slice {
		result = append(result, mapper(ele)...)
	}
	return result
}

func Chunk[T any](slice []T, size int) [][]T {
	var chunks [][]T
	for i := 0; i < len(slice); i += size {
		end := i + size
		if end > len(slice) {
			end = len(slice)
		}
		chunks = append(chunks, slice[i:end])
	}
	return chunks
}

func Unique[T comparable](slice []T) []T {
	seen := make(map[T]bool)
	result := make([]T, 0)
	for _, ele := range slice {
		if seen[ele] {
			continue
		}
		seen[ele] = true
		result = append(result, ele)
	}
	return result
}

func GroupBy[T any, K comparable](slice []T, keyGetter func(T) K) map[K][]T {
	result := make(map[K][]T, 0)
	for _, ele := range slice {
		key := keyGetter(ele)
		result[key] = append(result[key], ele)
	}
	return result
}

func Partition[T any](slice []T, predicate func(T) bool) ([]T, []T) {
	var truthy, falsy []T
	for _, item := range slice {
		if predicate(item) {
			truthy = append(truthy, item)
		} else {
			falsy = append(falsy, item)
		}
	}
	return truthy, falsy
}
