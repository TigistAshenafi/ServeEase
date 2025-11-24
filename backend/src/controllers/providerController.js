import Provider from "../models/Provider.js";

export const registerProvider = async (req, res) => {
  try {
    const { business_name, description } = req.body;
    const user_id = req.user.id;

    const existing = await Provider.findByUserId(user_id);
    if (existing)
      return res.status(400).json({ message: "You already registered as a provider." });

    const provider = await Provider.create(user_id, business_name, description);

    res.json({
      message: "Provider registration submitted. Awaiting approval.",
      provider,
    });
  } catch (error) {
    console.error("Provider Register Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMyProviderStatus = async (req, res) => {
  try {
    const provider = await Provider.findByUserId(req.user.id);
    res.json(provider || { status: "not_provider" });
  } catch (error) {
    console.error("Get Provider Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
