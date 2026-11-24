import os
import sys
from PIL import Image


def build_blank_button(source_dir, output_dir, state_index):
    button_names = [
        "dialog_but_accept",
        "dialog_but_ascend",
        "dialog_but_awesome",
        "dialog_but_buy",
        "dialog_but_decline",
        "dialog_but_descend",
        "dialog_but_dontbuy",
        "dialog_but_dontquit",
        "dialog_but_dontsell",
        "dialog_but_nay",
        "dialog_but_ok",
        "dialog_but_pickup",
        "dialog_but_quit",
        "dialog_but_sell",
        "dialog_but_shucks",
        "dialog_but_stay",
        "dialog_but_yea",
    ]
    loaded_images = []
    for name in button_names:
        file_path = os.path.join(source_dir, f"{name}{state_index}.png")
        if os.path.exists(file_path):
            loaded_images.append(Image.open(file_path).convert("RGBA"))
    if not loaded_images:
        raise FileNotFoundError(f"No source button images found in {source_dir}")
    width, height = loaded_images[0].size
    pixel_lists = [img.load() for img in loaded_images]
    output_image = Image.new("RGBA", (width, height))
    out_pixels = output_image.load()
    for yy in range(height):
        for xx in range(width):
            samples = [pixels[xx, yy] for pixels in pixel_lists]
            red = max(sample[0] for sample in samples)
            green = max(sample[1] for sample in samples)
            blue = max(sample[2] for sample in samples)
            alpha_values = sorted(sample[3] for sample in samples)
            alpha = alpha_values[len(alpha_values) // 2]
            out_pixels[xx, yy] = (red, green, blue, alpha)
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"dialog_but_blank{state_index}.png")
    output_image.save(output_path)
    return output_path


def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source_dir = os.path.join(repo_root, "airef", "steam-install", "ui")
    output_dir = os.path.join(repo_root, "asset", "ui", "generated")
    if len(sys.argv) > 1:
        source_dir = sys.argv[1]
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    states = [0, 1, 2]
    total_states = len(states)
    for idx, state_index in enumerate(states):
        out_path = build_blank_button(source_dir, output_dir, state_index)
        print(f"{idx + 1}/{total_states} Generated {out_path}")


if __name__ == "__main__":
    main()
