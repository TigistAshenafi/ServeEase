import Provider from "../models/Provider.js";
import db from "../config/db.js";

async function updateUserRole(userId, role) {
  if (!userId) return;
  await db.query('UPDATE users SET role=$1 WHERE id=$2', [role, userId]);
}
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
    if(!provider) return res.status(404).json({ message: "Provider not found" });
    await updateUserRole(provider.user_id, "provider");
    res.json({ message: "Provider approved", provider });
  } catch (error) {
    console.error("Approve Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const rejectProvider = async (req, res) => {
  try {
    const provider = await Provider.updateStatus(req.params.id, "rejected");
    if(!provider) return res.status(404).json({ message: "Provider not found" });
    await updateUserRole(provider.user_id, "seeker");
    res.json({ message: "Provider rejected", provider });
  } catch (error) {
    console.error("Reject Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const suspendProvider = async (req, res) => {
  try {
    const provider = await Provider.updateStatus(req.params.id, "suspended");
    if(!provider) return res.status(404).json({ message: "Provider not found" });
    await updateUserRole(provider.user_id, "seeker");
    res.json({ message: "Provider suspended", provider });
  } catch (error) {
    console.error("Suspend Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
