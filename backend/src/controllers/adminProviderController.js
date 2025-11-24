import Provider from "../models/Provider.js";

export const getAllProviders = async (req, res) => {
  try {
    const providers = await Provider.findAll();
    res.json(providers);
  } catch (error) {
    console.error("Admin Get Providers Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const approveProvider = async (req, res) => {
  try {
    const provider = await Provider.updateStatus(req.params.id, "approved");
    res.json({ message: "Provider approved", provider });
  } catch (error) {
    console.error("Approve Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const rejectProvider = async (req, res) => {
  try {
    const provider = await Provider.updateStatus(req.params.id, "rejected");
    res.json({ message: "Provider rejected", provider });
  } catch (error) {
    console.error("Reject Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const suspendProvider = async (req, res) => {
  try {
    const provider = await Provider.updateStatus(req.params.id, "suspended");
    res.json({ message: "Provider suspended", provider });
  } catch (error) {
    console.error("Suspend Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
