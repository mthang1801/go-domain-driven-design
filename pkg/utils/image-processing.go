package utils

import (
	"fmt"
	"image"
	"image/color"
	_ "image/gif"  // Import để hỗ trợ GIF
	_ "image/jpeg" // Import để hỗ trợ JPEG
	"image/png"
	"os"

	"path/filepath"

	"github.com/nfnt/resize"
)

func ReadImage(inputPath string) image.Image {
	fmt.Println("Reading image from:", inputPath)
	file, err := os.Open(inputPath)
	if err != nil {
		fmt.Printf("Error opening file %s: %v\n", inputPath, err)
		panic(err)
	}
	defer file.Close()

	img, format, err := image.Decode(file)
	if err != nil {
		fmt.Printf("Error decoding image %s: %v\n", inputPath, err)
		fmt.Printf("Supported formats: PNG, JPEG, GIF\n")
		panic(err)
	}

	fmt.Printf("Successfully decoded %s as %s format\n", inputPath, format)
	return img
}

func WriteImage(img image.Image, outputPath string) {
	err := os.MkdirAll(filepath.Dir(outputPath), os.ModePerm)
	if err != nil {
		fmt.Println("Error creating directories:", err)
		panic(err)
	}

	outputFile, err := os.Create(outputPath)
	if err != nil {
		fmt.Println("Error creating output file:", err)
		panic(err)
	}

	defer outputFile.Close()

	err = png.Encode(outputFile, img)
	if err != nil {
		fmt.Println("Error encoding image:", err)
		panic(err)
	}
}

func Grayscale(img image.Image) image.Image {
	bounds := img.Bounds()
	grayImg := image.NewGray(bounds)

	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			originalPixel := img.At(x, y)
			grayPixel := color.GrayModel.Convert(originalPixel)
			grayImg.Set(x, y, grayPixel)
		}
	}

	return grayImg
}

func Resize(img image.Image, width, height int) image.Image {
	newWidth := uint(width)
	newHeight := uint(height)
	scaledImg := resize.Resize(newWidth, newHeight, img, resize.Lanczos3)
	return scaledImg
}
